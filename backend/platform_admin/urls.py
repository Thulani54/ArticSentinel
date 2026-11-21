from django.urls import path
from . import views

urlpatterns = [
    path('login/', views.Login.as_view()),
    path('access/', views.Access.as_view()),
    path('password/', views.Password.as_view()),
    path('insights/', views.Insights.as_view()),
    path('overview/', views.Overview.as_view()),
    path('records/<str:resource>/', views.Records.as_view()),
    path('records/<str:resource>/<str:pk>/', views.Detail.as_view()),
    path('export/<str:resource>/', views.Export.as_view()),
]
