WITH UserBadgeCounts AS (
    SELECT 
        UserId, 
        COUNT(CASE WHEN Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN Class = 3 THEN 1 END) AS BronzeBadges
    FROM Badges
    GROUP BY UserId
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        (SELECT COUNT(*) FROM Comments C WHERE C.PostId = P.Id) AS CommentCount,
        P.Score,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS UserPostRank
    FROM Posts P
    LEFT JOIN Users U ON P.OwnerUserId = U.Id
    WHERE P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
VoteStatistics AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN VoteTypeId IN (6, 10) THEN 1 ELSE 0 END) AS CloseVotes
    FROM Votes
    GROUP BY PostId
),
CompositeRanking AS (
    SELECT 
        PD.PostId,
        PD.Title,
        PD.OwnerDisplayName,
        PD.CreationDate,
        COALESCE(UBC.GoldBadges, 0) AS GoldBadges,
        COALESCE(UBC.SilverBadges, 0) AS SilverBadges,
        COALESCE(UBC.BronzeBadges, 0) AS BronzeBadges,
        VS.UpVotes,
        VS.DownVotes,
        VS.CloseVotes,
        PD.CommentCount,
        RANK() OVER (ORDER BY (VS.UpVotes - VS.DownVotes) DESC) as PostRank
    FROM PostDetails PD
    LEFT JOIN UserBadgeCounts UBC ON PD.OwnerDisplayName = (SELECT DisplayName FROM Users WHERE Id = UBC.UserId)
    LEFT JOIN VoteStatistics VS ON PD.PostId = VS.PostId
)
SELECT 
    CR.PostId, 
    CR.Title, 
    CR.OwnerDisplayName,
    CR.GoldBadges,
    CR.SilverBadges,
    CR.BronzeBadges,
    CR.UpVotes,
    CR.DownVotes,
    CR.CommentCount,
    CR.PostRank
FROM CompositeRanking CR
WHERE CR.PostRank <= 10
ORDER BY CR.PostRank, CR.Title;