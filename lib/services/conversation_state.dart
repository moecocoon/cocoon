import 'conversation_context.dart';

class ConversationState {
  final ConversationContext context;

  const ConversationState(this.context);

  bool get knowsPerson {
    return context.currentPerson != null ||
        context.knows('work_supervisor');
  }

  bool get knowsProblemIsRepeated {
    return context.happenedRepeatedly == true ||
        context.knows('repeated_problem');
  }

  bool get knowsUserIsScared {
    return context.feelsScared == true ||
        context.knows('work_scared_of_supervisor');
  }

  bool get knowsUserWantsToAvoid {
    return context.wantsToAvoid == true ||
        context.knows('work_wants_to_avoid');
  }

  bool get knowsUserWantsToSolve {
  return context.wantsToSolve == true;
}

bool get knowsUserWantsSupport {
  return context.wantsSupport == true;
}

bool get hasEnoughContextToReflect {
  int knownFacts = 0;

  if (context.feelsScared == true) {
    knownFacts++;
  }

  if (context.happenedRepeatedly == true) {
    knownFacts++;
  }

  if (context.wantsToAvoid == true) {
    knownFacts++;
  }

  if (context.wantsToSolve == true) {
    knownFacts++;
  }

  if (context.wantsSupport == true) {
    knownFacts++;
  }

  if (context.currentPerson != null) {
    knownFacts++;
  }

  if (context.currentProblem != null) {
    knownFacts++;
  }

  return knownFacts >= 3;
}

  bool get knowsUserWantsToReconnect {
    return context.wantsToReconnect == true;
  }

  bool get knowsUserWantsToApologize {
    return context.wantsToApologize == true;
  }

  bool get knowsContactStatus {
    return context.isStillInContact != null;
  }

  bool get needsPersonInfo {
    return !knowsPerson;
  }

  bool get needsRepeatInfo {
    return !knowsProblemIsRepeated;
  }

  bool get needsFearInfo {
    return !knowsUserIsScared;
  }

  bool get needsContactInfo {
    return !knowsContactStatus;
  }
}