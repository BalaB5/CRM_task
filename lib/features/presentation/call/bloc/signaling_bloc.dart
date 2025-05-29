import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/app_constants.dart';
import '../../../../core/fcm_helper.dart';
import '../../../../core/ui_utils.dart';
import '../../../models/notification_payload.dart';
import '../../../models/user_model.dart';
import '../../../repositories/auth_repository.dart';

part 'signaling_event.dart';

part 'signaling_state.dart';

class SignalingBloc extends Bloc<SignalingEvent, SignalingState> {
  RTCPeerConnection? peerConnection;

  MediaStream? localStream;
  MediaStream? remoteStream;

  Function(MediaStream stream)? onAddRemoteStream;
  VoidCallback? onDisconnect;

  FirebaseFirestore db = FirebaseFirestore.instance;

  SignalingBloc() : super(SignalingInitialState()) {
    on<CreateRtcRoomEvent>(_createRoom);
    on<JoinRtcRoomEvent>(_joinRoom);
    on<HangUpCallEvent>(_hangUp);
    on<SignalingInitialEvent>((event, emit) => emit(SignalingInitialState()));
    on<SignalingConnectingEvent>(
      (event, emit) => emit(SignalingConnectingState()),
    );
    on<SignalingConnectedEvent>(
      (event, emit) => emit(SignalingConnectedState()),
    );
    on<SignalingDisConnectedEvent>(
      (event, emit) => emit(SignalingDisconnectedState()),
    );
  }

  Future<void> _createRoom(
    CreateRtcRoomEvent event,
    Emitter<SignalingState> emit,
  ) async {
    localStream = event.localStream;
    DocumentReference roomRef = db.collection('room').doc(event.roomId);

    UiUtils.showLog(
      'Create PeerConnection with configuration: ${AppConstants.webrtcConfiguration}',
    );
    peerConnection = await createPeerConnection(
      AppConstants.webrtcConfiguration,
    );

    registerPeerConnectionListeners();

    localStream?.getTracks().forEach((track) {
      peerConnection?.addTrack(track, localStream!);
    });

    // Code for collecting ICE candidates below
    var callerCandidatesCollection = roomRef.collection('callerCandidates');

    peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
      UiUtils.showLog('Got candidate: ${candidate.toMap()}');
      callerCandidatesCollection.add(candidate.toMap());
    };
    // Finish Code for collecting ICE candidate

    // Add code for creating a room
    RTCSessionDescription offer = await peerConnection!.createOffer();
    await peerConnection!.setLocalDescription(offer);
    UiUtils.showLog('Created offer: $offer');

    Map<String, dynamic> roomWithOffer = {'offer': offer.toMap()};

    await roomRef.set(roomWithOffer);
    var roomId = roomRef.id;
    UiUtils.showLog('New room created with SDK offer. Room ID: $roomId');
    // Created a Room

    peerConnection?.onTrack = (RTCTrackEvent event) {
      UiUtils.showLog('Got remote track: ${event.streams[0]}');

      event.streams[0].getTracks().forEach((track) {
        UiUtils.showLog('Add a track to the remoteStream $track');
        remoteStream?.addTrack(track);
      });
    };

    // Listening for remote session description below
    roomRef.snapshots().listen((snapshot) async {
      UiUtils.showLog('Got updated room: ${snapshot.data()}');

      if (snapshot.data() != null) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        if (peerConnection?.getRemoteDescription() != null &&
            data['answer'] != null) {
          var answer = RTCSessionDescription(
            data['answer']['sdp'],
            data['answer']['type'],
          );

          UiUtils.showLog("Someone tried to connect");
          await peerConnection?.setRemoteDescription(answer);
        }
      }
    });
    // Listening for remote session description above

    // Listen for remote Ice candidates below
    roomRef.collection('calleeCandidates').snapshots().listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          Map<String, dynamic> data = change.doc.data() as Map<String, dynamic>;
          UiUtils.showLog('Got new remote ICE candidate: ${jsonEncode(data)}');
          peerConnection!.addCandidate(
            RTCIceCandidate(
              data['candidate'],
              data['sdpMid'],
              data['sdpMLineIndex'],
            ),
          );
        }
      }
    });
    // Listen for remote ICE candidates above

    roomId = roomRef.id;
  }

  Future<void> _joinRoom(
    JoinRtcRoomEvent event,
    Emitter<SignalingState> emit,
  ) async {
    localStream = event.localStream;
    DocumentReference roomRef = db.collection('room').doc(event.roomId);
    var roomSnapshot = await roomRef.get();
    UiUtils.showLog('Got room ${roomSnapshot.exists}');

    if (roomSnapshot.exists) {
      UiUtils.showLog(
        'Create PeerConnection with configuration: ${AppConstants.webrtcConfiguration}',
      );
      peerConnection = await createPeerConnection(
        AppConstants.webrtcConfiguration,
      );

      registerPeerConnectionListeners();

      localStream?.getTracks().forEach((track) {
        peerConnection?.addTrack(track, localStream!);
      });

      // Code for collecting ICE candidates below
      var calleeCandidatesCollection = roomRef.collection('calleeCandidates');
      peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
        UiUtils.showLog('onIceCandidate: ${candidate.toMap()}');
        calleeCandidatesCollection.add(candidate.toMap());
      };
      // Code for collecting ICE candidate above

      peerConnection?.onTrack = (RTCTrackEvent event) {
        UiUtils.showLog('Got remote track: ${event.streams[0]}');
        event.streams[0].getTracks().forEach((track) {
          UiUtils.showLog('Add a track to the remoteStream: $track');
          remoteStream?.addTrack(track);
        });
      };

      // Code for creating SDP answer below
      var data = roomSnapshot.data() as Map<String, dynamic>;
      UiUtils.showLog('Got offer $data');
      var offer = data['offer'];
      await peerConnection?.setRemoteDescription(
        RTCSessionDescription(offer['sdp'], offer['type']),
      );
      var answer = await peerConnection!.createAnswer();
      UiUtils.showLog('Created Answer $answer');

      await peerConnection!.setLocalDescription(answer);

      Map<String, dynamic> roomWithAnswer = {
        'answer': {'type': answer.type, 'sdp': answer.sdp},
      };

      await roomRef.update(roomWithAnswer);
      // Finished creating SDP answer

      // Listening for remote ICE candidates below
      roomRef.collection('callerCandidates').snapshots().listen((snapshot) {
        for (var document in snapshot.docChanges) {
          var data = document.doc.data() as Map<String, dynamic>;
          UiUtils.showLog(data.toString());
          UiUtils.showLog('Got new remote ICE candidate: $data');
          peerConnection!.addCandidate(
            RTCIceCandidate(
              data['candidate'],
              data['sdpMid'],
              data['sdpMLineIndex'],
            ),
          );
        }
      });
    }
  }

  Future<void> _hangUp(
    HangUpCallEvent event,
    Emitter<SignalingState> emit,
  ) async {
    try {
      //close media & connection

      List<MediaStreamTrack>? tracks = event.localRender.srcObject?.getTracks();
      tracks?.forEach((track) {
        track.stop();
      });

      if (remoteStream != null) {
        remoteStream?.getTracks().forEach((track) => track.stop());
      }

      dispose();

      //clear from firebase collection

      var roomRef = db.collection('room').doc(event.payload.webrtcRoomId);
      final snapshot =
          await FirebaseFirestore.instance.collection('users').get();
      User auth = GetIt.instance<AuthRepository>().currentUser!;
      final customers =
          snapshot.docs
              .where((doc) {
                return doc['email'] == auth.email;
              })
              .map((doc) => UserModel.fromMap(doc.id, doc.data()))
              .toList();
      UserModel currentUser = customers[0];
      await roomRef.get().then((value) async {
        if (value.data()?.containsKey('answer') == false) {
          event.payload.userId = currentUser.uid;
          event.payload.name = currentUser.fullName;
          event.payload.username = currentUser.username;
        
          event.payload.fcmToken = currentUser.fcmToken;
          event.payload.callAction = CallAction.end;
          await FCMHelper.sendNotification(
            fcmToken: event.payload.fcmToken ?? '',
            payload: event.payload,
          );
        }
      });

      var calleeCandidates = await roomRef.collection('calleeCandidates').get();
      for (var document in calleeCandidates.docs) {
        document.reference.delete();
      }

      var callerCandidates = await roomRef.collection('callerCandidates').get();
      for (var document in callerCandidates.docs) {
        document.reference.delete();
      }

      await roomRef.delete();
    } on Exception catch (e) {
      UiUtils.showLog(e.toString());
      emit(SignalingFailureState());
    }
  }

  void registerPeerConnectionListeners() {
    peerConnection?.onIceGatheringState = (RTCIceGatheringState state) {
      UiUtils.showLog('ICE gathering state changed: $state');
    };

    peerConnection?.onConnectionState = (RTCPeerConnectionState state) {
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
        onDisconnect?.call();
        add(SignalingDisConnectedEvent());
      } else if (state ==
          RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        add(SignalingConnectedEvent());
      } else if (state ==
          RTCPeerConnectionState.RTCPeerConnectionStateConnecting) {
        add(SignalingConnectingEvent());
      }
      UiUtils.showLog('Connection state change: $state ${DateTime.now()}');
    };

    peerConnection?.onSignalingState = (RTCSignalingState state) {
      UiUtils.showLog('Signaling state change: $state');
    };

    peerConnection?.onIceGatheringState = (RTCIceGatheringState state) {
      UiUtils.showLog('ICE connection state change: $state');
    };

    peerConnection?.onAddStream = (MediaStream stream) {
      UiUtils.showLog("Add remote stream");
      onAddRemoteStream?.call(stream);
      remoteStream = stream;
    };
  }

  void dispose() {
    peerConnection?.close();
    localStream?.dispose();
    remoteStream?.dispose();
  }
}
