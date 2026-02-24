
WITH PostStats AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        COALESCE(A.AnswerCount, 0) AS AnswerCount,
        COALESCE(C.CommentCount, 0) AS CommentCount,
        COALESCE(V.UpVotes, 0) AS UpVotes,
        COALESCE(V.DownVotes, 0) AS DownVotes,
        U.DisplayName AS OwnerDisplayName
    FROM 
        Posts P
    LEFT JOIN (
        SELECT ParentId, COUNT(*) AS AnswerCount
        FROM Posts
        WHERE PostTypeId = 2
        GROUP BY ParentId
    ) A ON P.Id = A.ParentId
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS CommentCount
        FROM Comments
        GROUP BY PostId
    ) C ON P.Id = C.PostId
    LEFT JOIN (
        SELECT PostId,
               SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
               SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
        FROM Votes
        GROUP BY PostId
    ) V ON P.Id = V.PostId
    LEFT JOIN Users U ON P.OwnerUserId = U.Id
    WHERE P.PostTypeId = 1 
),
UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS QuestionCount,
        SUM(P.Score) AS TotalScore,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId AND P.PostTypeId = 1
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
)
SELECT 
    PS.Title,
    PS.CreationDate,
    PS.ViewCount,
    PS.Score,
    PS.AnswerCount,
    PS.CommentCount,
    PS.UpVotes,
    PS.DownVotes,
    PS.OwnerDisplayName,
    US.UserId,
    US.DisplayName AS UserDisplayName,
    US.QuestionCount,
    US.TotalScore,
    US.GoldBadges,
    US.SilverBadges,
    US.BronzeBadges
FROM 
    PostStats PS
JOIN 
    UserStats US ON PS.OwnerDisplayName = US.DisplayName
ORDER BY 
    PS.ViewCount DESC, US.QuestionCount DESC
LIMIT 100;
