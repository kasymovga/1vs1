float c1, c2, c3, c4;
void CheckAllowedTeams (entity for_whom);

// NOTE: SP_ constants may not be >= MAX_SCORE; ST_constants may not be >= MAX_TEAMSCORE
// scores that should be in all modes:
float ScoreRules_teams;
void ScoreRules_basics(float sprio, float stprio, float score_enabled)
{
	CheckAllowedTeams(world);
	float i;
	scores_preinitialized = 1;
	for(i = 0; i < MAX_SCORE; ++i)
		ScoreInfo_SetLabel_PlayerScore(i, "", 0);
	for(i = 0; i < MAX_TEAMSCORE; ++i)
		ScoreInfo_SetLabel_TeamScore(i, "", 0);

	ScoreRules_teams = 4 + c1 + c2 + c3 + c4;

	if(score_enabled)
		ScoreInfo_SetLabel_TeamScore  (ST_SCORE,        "score",     stprio);

	if not(independent_players)
		ScoreInfo_SetLabel_PlayerScore(SP_KILLS,        "kills",     0);

	ScoreInfo_SetLabel_PlayerScore(SP_DEATHS,       "deaths",    SFL_LOWER_IS_BETTER);

	if not(independent_players)
		ScoreInfo_SetLabel_PlayerScore(SP_SUICIDES,     "suicides",  SFL_LOWER_IS_BETTER);

	if(score_enabled)
		ScoreInfo_SetLabel_PlayerScore(SP_SCORE,        "score",     sprio);
}
void ScoreRules_basics_end()
{
	ScoreInfo_Init(ScoreRules_teams);
}
void ScoreRules_generic()
{
	ScoreRules_basics(SFL_SORT_PRIO_PRIMARY, SFL_SORT_PRIO_PRIMARY, TRUE);
}
