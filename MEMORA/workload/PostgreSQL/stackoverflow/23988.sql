WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title, 
        P.CreationDate,
        P.OwnerUserId,
        U.Reputation,
        RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
UserBadges AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) FILTER (WHERE B.Class = 1) AS GoldBadges,
        COUNT(B.Id) FILTER (WHERE B.Class = 2) AS SilverBadges,
        COUNT(B.Id) FILTER (WHERE B.Class = 3) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
PostScoreSummary AS (
    SELECT 
        P.Id AS PostId,
        COALESCE(V.TotalVotes, 0) AS VoteCount,
        COALESCE(C.CommentCount, 0) AS CommentCount,
        COALESCE(A.AnswerCount, 0) AS AnswerCount
    FROM 
        Posts P
    LEFT JOIN (
        SELECT 
            PostId, COUNT(*) AS TotalVotes
        FROM 
            Votes
        GROUP BY 
            PostId
    ) V ON P.Id = V.PostId
    LEFT JOIN (
        SELECT 
            PostId, COUNT(*) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) C ON P.Id = C.PostId
    LEFT JOIN (
        SELECT 
            ParentId AS PostId, COUNT(*) AS AnswerCount
        FROM 
            Posts
        WHERE 
            PostTypeId = 2 
        GROUP BY 
            ParentId
    ) A ON P.Id = A.PostId
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.CreationDate,
    U.DisplayName,
    U.Reputation,
    UB.GoldBadges,
    UB.SilverBadges,
    UB.BronzeBadges,
    PS.VoteCount,
    PS.CommentCount,
    PS.AnswerCount,
    CASE 
        WHEN PS.AnswerCount = 0 THEN 'No Answers'
        WHEN PS.AnswerCount > 0 AND PS.VoteCount = 0 THEN 'Needs Attention'
        ELSE 'Active' 
    END AS PostStatus,
    COUNT(DISTINCT C.Id) AS TotalPostHistoryChanges
FROM 
    RankedPosts RP
JOIN 
    Users U ON RP.OwnerUserId = U.Id
JOIN 
    UserBadges UB ON U.Id = UB.UserId
JOIN 
    PostScoreSummary PS ON RP.PostId = PS.PostId
LEFT JOIN 
    PostHistory PH ON RP.PostId = PH.PostId
LEFT JOIN 
    Comments C ON RP.PostId = C.PostId
WHERE 
    (RP.PostRank = 1 AND PS.VoteCount > 0) 
    OR (RP.PostRank = 1 AND PS.CommentCount > 5)
GROUP BY 
    RP.PostId, RP.Title, RP.CreationDate, U.DisplayName, U.Reputation, 
    UB.GoldBadges, UB.SilverBadges, UB.BronzeBadges, PS.VoteCount, 
    PS.CommentCount, PS.AnswerCount
ORDER BY 
    PS.VoteCount DESC, RP.CreationDate DESC
LIMIT 100;