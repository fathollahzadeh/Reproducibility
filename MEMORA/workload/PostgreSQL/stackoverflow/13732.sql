
WITH PostVoteStats AS (
    SELECT 
        P.Id AS PostId,
        P.PostTypeId,
        P.Score,
        P.ViewCount,
        COUNT(V.Id) AS VoteCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.PostTypeId, P.Score, P.ViewCount
),
UserStats AS (
    SELECT
        U.Id AS UserId,
        U.Reputation,
        COUNT(B.Id) AS BadgeCount,
        SUM(P.ViewCount) AS TotalPostViews,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.Reputation
)
SELECT 
    PVS.PostId,
    PVS.PostTypeId,
    PVS.Score,
    PVS.ViewCount,
    PVS.VoteCount,
    PVS.UpVotes,
    PVS.DownVotes,
    US.UserId,
    US.Reputation,
    US.BadgeCount,
    US.TotalPostViews,
    US.QuestionCount,
    US.AnswerCount
FROM 
    PostVoteStats PVS
JOIN 
    UserStats US ON PVS.PostId = US.UserId
ORDER BY 
    PVS.Score DESC, PVS.ViewCount DESC
LIMIT 100;
