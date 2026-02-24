WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM 
        Users U
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        COUNT(C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN V.VoteTypeId = 10 THEN 1 ELSE 0 END) AS DeletionCount,
        COALESCE(P.ViewCount, 0) AS ViewCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        P.Id, P.Title, P.ViewCount
),
DetailedPostStats AS (
    SELECT 
        PS.PostId,
        PS.Title,
        PS.CommentCount,
        PS.UpVotes,
        PS.DownVotes,
        PS.DeletionCount,
        PS.ViewCount,
        CASE 
            WHEN PS.UpVotes > PS.DownVotes THEN 'Positive'
            WHEN PS.UpVotes < PS.DownVotes THEN 'Negative'
            ELSE 'Neutral'
        END AS Sentiment
    FROM 
        PostStats PS
),
UserBadgeStats AS (
    SELECT 
        B.UserId,
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges B
    GROUP BY 
        B.UserId
),
FinalStats AS (
    SELECT 
        U.UserId,
        U.Reputation,
        U.ReputationRank,
        DPS.Title,
        DPS.CommentCount,
        DPS.UpVotes,
        DPS.DownVotes,
        DPS.ViewCount,
        UBS.GoldBadges,
        UBS.SilverBadges,
        UBS.BronzeBadges,
        DPS.Sentiment
    FROM 
        UserReputation U
    LEFT JOIN 
        DetailedPostStats DPS ON U.UserId = DPS.PostId
    LEFT JOIN 
        UserBadgeStats UBS ON U.UserId = UBS.UserId
)
SELECT 
    FS.UserId,
    FS.Reputation,
    FS.ReputationRank,
    COALESCE(FS.Title, 'No Posts') AS PostTitle,
    FS.CommentCount,
    FS.UpVotes,
    FS.DownVotes,
    FS.ViewCount,
    COALESCE(FS.GoldBadges, 0) AS GoldBadges,
    COALESCE(FS.SilverBadges, 0) AS SilverBadges,
    COALESCE(FS.BronzeBadges, 0) AS BronzeBadges,
    FS.Sentiment,
    CASE 
        WHEN FS.ViewCount > 100 THEN 'Highly Viewed'
        WHEN FS.ViewCount BETWEEN 50 AND 100 THEN 'Moderately Viewed'
        ELSE 'Less Viewed'
    END AS ViewershipCategory
FROM 
    FinalStats FS
WHERE 
    FS.ReputationRank <= 100 OR FS.UpVotes > 0
ORDER BY 
    FS.Reputation DESC, FS.CommentCount ASC NULLS LAST;