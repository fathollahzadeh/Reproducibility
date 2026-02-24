WITH UserActivity AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsAsked,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersGiven,
        COUNT(CM.Id) AS CommentCount,
        COUNT(V.Id) AS VoteCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments CM ON P.Id = CM.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY U.Id, U.DisplayName
), UserRanked AS (
    SELECT 
        UserId, 
        DisplayName,
        QuestionsAsked,
        AnswersGiven,
        CommentCount,
        VoteCount,
        UpVotes,
        DownVotes,
        RANK() OVER (ORDER BY QuestionsAsked DESC, UpVotes DESC) AS UserRank
    FROM UserActivity
), UserBadges AS (
    SELECT 
        B.UserId,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM 
        Badges B
    GROUP BY B.UserId
)
SELECT 
    U.UserId, 
    U.DisplayName, 
    U.QuestionsAsked, 
    U.AnswersGiven, 
    U.CommentCount, 
    U.VoteCount, 
    U.UpVotes, 
    U.DownVotes, 
    COALESCE(UB.BadgeNames, 'No Badges') AS Badges,
    U.UserRank
FROM 
    UserRanked U
LEFT JOIN UserBadges UB ON U.UserId = UB.UserId
WHERE 
    U.UserRank <= 10
ORDER BY 
    U.UserRank;
