
WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        COUNT(C) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        DENSE_RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS UserPostRank
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY P.Id, P.Title, P.CreationDate, P.OwnerUserId
),
PopularPosts AS (
    SELECT 
        PD.PostId,
        PD.Title,
        PD.CreationDate,
        PD.CommentCount,
        PD.UpVotes,
        PD.DownVotes,
        U.DisplayName,
        UB.GoldBadges,
        UB.SilverBadges,
        UB.BronzeBadges
    FROM PostDetails PD
    JOIN Users U ON PD.OwnerUserId = U.Id
    LEFT JOIN UserBadges UB ON U.Id = UB.UserId
    WHERE PD.UpVotes - PD.DownVotes > 5
    ORDER BY PD.UpVotes DESC
),
OverallPerformance AS (
    SELECT 
        PostId,
        Title,
        CommentCount,
        UpVotes - DownVotes AS NetScore,
        GoldBadges,
        SilverBadges,
        BronzeBadges,
        CASE 
            WHEN GoldBadges > 0 THEN 'High Contributor'
            WHEN SilverBadges > 0 THEN 'Contributor'
            ELSE 'New Member'
        END AS MemberType
    FROM PopularPosts
)
SELECT 
    *,
    CASE 
        WHEN MemberType = 'High Contributor' AND NetScore > 20 THEN 'Top Performer'
        WHEN MemberType = 'Contributor' AND NetScore BETWEEN 10 AND 20 THEN 'Regular Performer'
        ELSE 'Needs Improvement'
    END AS PerformanceCategory
FROM OverallPerformance
WHERE NetScore IS NOT NULL
ORDER BY NetScore DESC, CommentCount DESC;
