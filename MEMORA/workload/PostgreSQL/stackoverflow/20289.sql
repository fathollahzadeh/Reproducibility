
WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostInfo AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        COALESCE(P.AcceptedAnswerId, -1) AS AcceptedAnswerId,
        COALESCE(P.ViewCount, 0) AS ViewCount,
        SUM(CASE WHEN C.PostId IS NOT NULL THEN 1 ELSE 0 END) AS CommentCount,
        COUNT(V.Id) FILTER (WHERE V.VoteTypeId = 2) AS UpVotes,
        COUNT(V.Id) FILTER (WHERE V.VoteTypeId = 3) AS DownVotes
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.OwnerUserId, P.AcceptedAnswerId
),
RankedPosts AS (
    SELECT 
        PI.*,
        RANK() OVER (ORDER BY PI.ViewCount DESC) AS RankByView,
        RANK() OVER (ORDER BY (PI.UpVotes - PI.DownVotes) DESC) AS RankByVote
    FROM 
        PostInfo PI
    WHERE 
        PI.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
)
SELECT 
    U.DisplayName AS UserName,
    RP.Title AS PostTitle,
    RP.CreationDate AS PostCreated,
    RP.ViewCount,
    RP.UpVotes,
    RP.DownVotes,
    RP.RankByView,
    RP.RankByVote,
    UB.GoldBadges,
    UB.SilverBadges,
    UB.BronzeBadges,
    CASE 
        WHEN RP.AcceptedAnswerId <> -1 THEN 'Accepted Answer Exists' 
        ELSE 'No Accepted Answer' 
    END AS AcceptedAnswerStatus
FROM 
    RankedPosts RP
JOIN 
    Users U ON RP.OwnerUserId = U.Id
JOIN 
    UserBadges UB ON U.Id = UB.UserId
WHERE 
    (UB.BadgeCount IS NULL OR UB.BadgeCount > 0) 
    AND RP.RankByView <= 10
ORDER BY 
    RP.RankByView, RP.RankByVote DESC 
LIMIT 25;
