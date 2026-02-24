WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        (SELECT COUNT(*) FROM Comments C WHERE C.UserId = U.Id) AS TotalComments
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostEngagement AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.CreationDate,
        COUNT(C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.Title, P.ViewCount, P.CreationDate
),
ActiveUsers AS (
    SELECT 
        UA.UserId,
        UA.DisplayName,
        UA.PostCount,
        UA.QuestionCount,
        UA.AnswerCount,
        UA.UpVotes,
        UA.DownVotes,
        UA.GoldBadges,
        UA.SilverBadges,
        UA.BronzeBadges,
        UA.TotalComments,
        PE.PostId,
        PE.Title,
        PE.ViewCount,
        PE.CommentCount,
        PE.UpVotes AS PostUpVotes,
        PE.DownVotes AS PostDownVotes
    FROM 
        UserActivity UA
    JOIN 
        PostEngagement PE ON UA.UserId = PE.PostId
    WHERE 
        UA.PostCount > 5
)
SELECT 
    UserId,
    DisplayName,
    PostCount,
    QuestionCount,
    AnswerCount,
    UpVotes,
    DownVotes,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    TotalComments,
    Title,
    ViewCount,
    CommentCount,
    PostUpVotes,
    PostDownVotes
FROM 
    ActiveUsers
ORDER BY 
    PostCount DESC, UpVotes DESC
LIMIT 100;
