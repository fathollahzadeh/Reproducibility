WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS Rank
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
RecentVotes AS (
    SELECT 
        V.PostId, 
        COUNT(V.Id) AS VoteCount
    FROM 
        Votes V
    WHERE 
        V.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 month'
    GROUP BY 
        V.PostId
),
PostDetails AS (
    SELECT 
        R.PostId,
        R.Title,
        R.CreationDate,
        R.Score,
        R.ViewCount,
        COALESCE(RV.VoteCount, 0) AS RecentVoteCount,
        P.AcceptedAnswerId IS NOT NULL AS HasAcceptedAnswer
    FROM 
        RankedPosts R
    LEFT JOIN 
        RecentVotes RV ON R.PostId = RV.PostId
    LEFT JOIN 
        Posts P ON P.Id = R.PostId
    WHERE 
        R.Rank <= 10
),
TopUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        ROW_NUMBER() OVER (ORDER BY SUM(B.Class) DESC) AS BadgeRank
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
FinalResults AS (
    SELECT 
        PD.Title,
        PD.CreationDate,
        PD.Score,
        PD.ViewCount,
        PD.RecentVoteCount,
        U.DisplayName AS TopUserName,
        U.GoldBadges,
        U.SilverBadges,
        U.BronzeBadges
    FROM 
        PostDetails PD
    LEFT JOIN 
        TopUsers U ON U.BadgeRank = 1
)
SELECT 
    Title,
    CreationDate,
    Score,
    ViewCount,
    RecentVoteCount,
    COALESCE(TopUserName, 'No top user') AS TopUserName,
    GoldBadges,
    SilverBadges,
    BronzeBadges
FROM 
    FinalResults
ORDER BY 
    Score DESC, 
    ViewCount DESC;