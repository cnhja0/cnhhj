import 'package:flutter/material.dart';

import '../../models/booking.dart';
import '../../models/conversation.dart';
import '../../models/enums.dart';
import '../../models/instructor.dart';
import '../../models/message.dart';
import '../../models/profile.dart';
import '../../models/review.dart';
import '../../models/student.dart';
import '../../models/weekly_availability.dart';

/// Estado global de dados mockados, compartilhado por todas as implementações
/// `Mock*Repository`. Centralizar aqui evita inconsistências entre repos
/// (ex: uma booking referenciando um student que não existe).
///
/// Em produção (modo `supabase`), nada disso é usado.
class MockState {
  MockState._();
  static final MockState instance = MockState._()..seed();

  /// IDs fixos para facilitar o desenvolvimento.
  static const String currentInstructorId = 'instructor-001';

  // Senhas em texto puro — É MOCK, NÃO usar em produção.
  final Map<String, ({String userId, String password})> emailToCredentials =
      <String, ({String userId, String password})>{
    'instrutor@cnhhj.com.br': (userId: currentInstructorId, password: '123456'),
  };

  final Map<String, Profile> profiles = <String, Profile>{};
  final Map<String, Instructor> instructors = <String, Instructor>{};
  final Map<String, Student> students = <String, Student>{};
  final List<WeeklyAvailability> availability = <WeeklyAvailability>[];
  final List<Booking> bookings = <Booking>[];
  final List<Conversation> conversations = <Conversation>[];
  final Map<String, List<Message>> messagesByConversation =
      <String, List<Message>>{};
  final List<Review> reviews = <Review>[];

  void seed() {
    if (profiles.isNotEmpty) return;

    final DateTime now = DateTime.now();

    // ─── Profile + Instructor logado ─────────────────────────────────
    final Profile instructorProfile = Profile(
      id: currentInstructorId,
      role: UserRole.instrutor,
      fullName: 'Carlos Silva',
      cpf: '123.456.789-00',
      birthDate: DateTime(1985, 4, 12),
      gender: Gender.masculino,
      phone: '(11) 91234-5678',
      avatarUrl: null,
      approvalStatus: ApprovalStatus.approved,
      approvedAt: now.subtract(const Duration(days: 30)),
      createdAt: now.subtract(const Duration(days: 30)),
      updatedAt: now,
    );
    profiles[instructorProfile.id] = instructorProfile;

    instructors[currentInstructorId] = Instructor(
      id: currentInstructorId,
      bio: 'Instrutor há 10 anos, paciente e didático.',
      state: 'SP',
      city: 'Guarulhos',
      neighborhood: 'Vila Galvão',
      serviceRadiusKm: 8,
      vehicleType: VehicleType.carro,
      vehicleBrand: 'Volkswagen',
      vehicleModel: 'Gol',
      vehicleYear: 2022,
      vehicleTransmission: Transmission.manual,
      vehiclePlate: 'ABC-1D23',
      categories: const <VehicleCategory>[VehicleCategory.B],
      pricePerClass: 80,
      isActive: true,
      averageRating: 4.8,
      totalReviews: 12,
      createdAt: now.subtract(const Duration(days: 30)),
      updatedAt: now,
    );

    // ─── Alguns alunos ───────────────────────────────────────────────
    final List<({String id, String name})> studentsSeed = <({String id, String name})>[
      (id: 'student-001', name: 'Juliana Souza'),
      (id: 'student-002', name: 'Pedro Henrique'),
      (id: 'student-003', name: 'Mariana Lima'),
    ];
    for (final ({String id, String name}) s in studentsSeed) {
      profiles[s.id] = Profile(
        id: s.id,
        role: UserRole.aluno,
        fullName: s.name,
        approvalStatus: ApprovalStatus.approved,
        createdAt: now.subtract(const Duration(days: 20)),
        updatedAt: now,
      );
      students[s.id] = Student(
        id: s.id,
        desiredCategory: VehicleCategory.B,
        state: 'SP',
        city: 'Guarulhos',
        createdAt: now.subtract(const Duration(days: 20)),
        updatedAt: now,
      );
    }

    // ─── Grade semanal ───────────────────────────────────────────────
    availability.addAll(<WeeklyAvailability>[
      WeeklyAvailability(
        id: 'avail-1',
        instructorId: currentInstructorId,
        dayOfWeek: DayOfWeek.segunda,
        startTime: const TimeOfDay(hour: 8, minute: 0),
        endTime: const TimeOfDay(hour: 12, minute: 0),
        createdAt: now,
      ),
      WeeklyAvailability(
        id: 'avail-2',
        instructorId: currentInstructorId,
        dayOfWeek: DayOfWeek.terca,
        startTime: const TimeOfDay(hour: 14, minute: 0),
        endTime: const TimeOfDay(hour: 18, minute: 0),
        createdAt: now,
      ),
      WeeklyAvailability(
        id: 'avail-3',
        instructorId: currentInstructorId,
        dayOfWeek: DayOfWeek.quinta,
        startTime: const TimeOfDay(hour: 14, minute: 0),
        endTime: const TimeOfDay(hour: 18, minute: 0),
        createdAt: now,
      ),
    ]);

    // ─── Bookings: 2 pendentes, 1 confirmada, 1 concluída ────────────
    bookings.addAll(<Booking>[
      Booking(
        id: 'book-001',
        instructorId: currentInstructorId,
        studentId: 'student-001',
        scheduledStart: now.add(const Duration(days: 2, hours: 10)),
        scheduledEnd: now.add(const Duration(days: 2, hours: 11)),
        status: BookingStatus.pending,
        agreedPrice: 80,
        meetingPoint: 'Em frente ao mercado da Vila Galvão',
        createdAt: now.subtract(const Duration(hours: 3)),
        updatedAt: now.subtract(const Duration(hours: 3)),
      ),
      Booking(
        id: 'book-002',
        instructorId: currentInstructorId,
        studentId: 'student-002',
        scheduledStart: now.add(const Duration(days: 3, hours: 14)),
        scheduledEnd: now.add(const Duration(days: 3, hours: 15)),
        status: BookingStatus.pending,
        agreedPrice: 80,
        createdAt: now.subtract(const Duration(hours: 1)),
        updatedAt: now.subtract(const Duration(hours: 1)),
      ),
      Booking(
        id: 'book-003',
        instructorId: currentInstructorId,
        studentId: 'student-003',
        scheduledStart: now.add(const Duration(days: 1, hours: 9)),
        scheduledEnd: now.add(const Duration(days: 1, hours: 10)),
        status: BookingStatus.confirmed,
        agreedPrice: 80,
        meetingPoint: 'Praça da Vila Galvão',
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(hours: 12)),
      ),
      Booking(
        id: 'book-004',
        instructorId: currentInstructorId,
        studentId: 'student-001',
        scheduledStart: now.subtract(const Duration(days: 5)),
        scheduledEnd: now.subtract(const Duration(days: 5, hours: -1)),
        status: BookingStatus.completed,
        agreedPrice: 80,
        createdAt: now.subtract(const Duration(days: 6)),
        updatedAt: now.subtract(const Duration(days: 5)),
      ),
    ]);

    // ─── Conversas + mensagens ──────────────────────────────────────
    final Conversation conv1 = Conversation(
      id: 'conv-001',
      instructorId: currentInstructorId,
      studentId: 'student-001',
      lastMessageAt: now.subtract(const Duration(minutes: 30)),
      createdAt: now.subtract(const Duration(days: 6)),
    );
    final Conversation conv2 = Conversation(
      id: 'conv-002',
      instructorId: currentInstructorId,
      studentId: 'student-003',
      lastMessageAt: now.subtract(const Duration(hours: 12)),
      createdAt: now.subtract(const Duration(days: 1)),
    );
    conversations.addAll(<Conversation>[conv1, conv2]);

    messagesByConversation[conv1.id] = <Message>[
      Message(
        id: 'msg-1',
        conversationId: conv1.id,
        senderId: 'student-001',
        content: 'Oi! Tudo bem? Confirma a aula amanhã?',
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      Message(
        id: 'msg-2',
        conversationId: conv1.id,
        senderId: currentInstructorId,
        content: 'Oi Juliana! Sim, confirmado. Te encontro às 10h.',
        readAt: now.subtract(const Duration(hours: 1)),
        createdAt: now.subtract(const Duration(hours: 1)),
      ),
      Message(
        id: 'msg-3',
        conversationId: conv1.id,
        senderId: 'student-001',
        content: 'Perfeito! Até lá 😊',
        createdAt: now.subtract(const Duration(minutes: 30)),
      ),
    ];

    messagesByConversation[conv2.id] = <Message>[
      Message(
        id: 'msg-4',
        conversationId: conv2.id,
        senderId: 'student-003',
        content: 'Pode marcar uma aula sexta de manhã?',
        createdAt: now.subtract(const Duration(hours: 12)),
      ),
    ];

    // ─── Avaliações recebidas ───────────────────────────────────────
    reviews.add(
      Review(
        id: 'rev-001',
        bookingId: 'book-004',
        reviewerId: 'student-001',
        revieweeId: currentInstructorId,
        target: ReviewTarget.instructor,
        rating: 5,
        comment: 'Muito paciente e atencioso! Recomendo.',
        createdAt: now.subtract(const Duration(days: 4)),
      ),
    );
  }
}
