
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN C.Id IS NOT NULL THEN 1 ELSE 0 END) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.UserId = U.Id
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    WHERE 
        U.CreationDate < TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        U.Id, U.DisplayName
),
UserRanked AS (
    SELECT 
        UserId, 
        DisplayName,
        QuestionCount,
        AnswerCount,
        CommentCount,
        UpVotes,
        DownVotes,
        BadgeCount,
        RANK() OVER (ORDER BY QuestionCount DESC, AnswerCount DESC, UpVotes DESC) AS Rank
    FROM 
        UserActivity
)
SELECT 
    UR.DisplayName,
    UR.QuestionCount,
    UR.AnswerCount,
    UR.CommentCount,
    UR.UpVotes,
    UR.DownVotes,
    UR.BadgeCount,
    (UR.QuestionCount + UR.AnswerCount * 2 + UR.UpVotes - UR.DownVotes) AS EngagementScore
FROM 
    UserRanked UR
WHERE 
    UR.Rank <= 10
ORDER BY 
    EngagementScore DESC;
