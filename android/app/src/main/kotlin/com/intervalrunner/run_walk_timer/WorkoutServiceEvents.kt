package com.intervalrunner.run_walk_timer

object WorkoutServiceEvents {
    @Volatile
    var listener: ((HashMap<String, Any?>) -> Unit)? = null

    fun emit(state: HashMap<String, Any?>) {
        listener?.invoke(state)
    }
}
