enum SolutionStep {
  none,
  chooseDirection,
  chooseAction,
  makePlan,
  complete,
}

class SolutionFlow {
  SolutionStep currentStep = SolutionStep.none;

  void start() {
    currentStep = SolutionStep.chooseDirection;
  }

  void chooseDirection() {
    currentStep = SolutionStep.chooseAction;
  }

  void chooseAction() {
    currentStep = SolutionStep.makePlan;
  }

  void complete() {
    currentStep = SolutionStep.complete;
  }

  void reset() {
    currentStep = SolutionStep.none;
  }

  bool get isActive {
    return currentStep != SolutionStep.none &&
        currentStep != SolutionStep.complete;
  }

  bool get needsDirection {
    return currentStep == SolutionStep.chooseDirection;
  }

  bool get needsAction {
    return currentStep == SolutionStep.chooseAction;
  }

  bool get needsPlan {
    return currentStep == SolutionStep.makePlan;
  }

  bool get isComplete {
    return currentStep == SolutionStep.complete;
  }
}