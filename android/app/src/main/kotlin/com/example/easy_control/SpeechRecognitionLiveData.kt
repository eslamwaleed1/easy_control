package com.example.easy_control

import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData

object SpeechRecognitionLiveData {
    private val _recognizedWord = MutableLiveData<String>()
    val recognizedWord: LiveData<String> get() = _recognizedWord

    fun postRecognizedWord(word: String) {
        _recognizedWord.postValue(word)
    }
}