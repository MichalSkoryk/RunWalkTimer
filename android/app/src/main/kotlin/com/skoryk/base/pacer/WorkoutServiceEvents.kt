package com.skoryk.base.pacer

object WorkoutServiceEvents {
    @Volatile
    var listener: ((HashMap<String, Any?>) -> Unit)? = null

    fun emit(state: HashMap<String, Any?>) {
        listener?.invoke(state)
    }
}
