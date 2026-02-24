WITH RankedVotes AS (
    SELECT 
        P.Id AS PostId,
        V.VoteTypeId,
        COUNT(*) OVER (PARTITION BY P.Id, V.VoteTypeId) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY P.Id ORDER BY COUNT(*) DESC) as VoteRank
    FROM Votes V
    JOIN Posts P ON P.Id = V.PostId
    GROUP BY P.Id, V.VoteTypeId
),
RecentPostHistory AS (
    SELECT 
        PH.PostId,
        PH.PostHistoryTypeId,
        PH.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate DESC) AS RowNum
    FROM PostHistory PH
    WHERE PH.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
FilteredPosts AS (
    SELECT 
        P.Id,
        P.Title,
        COALESCE(RV.VoteCount, 0) AS Upvotes,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        MAX(RPH.CreationDate) AS LastEditDate
    FROM Posts P
    LEFT JOIN RankedVotes RV ON P.Id = RV.PostId AND RV.VoteTypeId = 2
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Badges B ON P.OwnerUserId = B.UserId
    LEFT JOIN RecentPostHistory RPH ON P.Id = RPH.PostId AND RPH.RowNum = 1
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '2 years'
        AND (P.ClosedDate IS NULL OR P.AcceptedAnswerId IS NOT NULL)
        AND P.ViewCount > 100
    GROUP BY P.Id, P.Title, RV.VoteCount
),
ExtendedAnalytics AS (
    SELECT 
        FP.*, 
        DENSE_RANK() OVER (ORDER BY FP.Upvotes DESC) AS RankByUpvotes,
        COUNT(*) OVER () AS TotalPosts
    FROM FilteredPosts FP
)
SELECT 
    EA.Title,
    EA.Upvotes,
    EA.CommentCount,
    EA.BadgeCount,
    EA.LastEditDate,
    CASE 
        WHEN EA.RankByUpvotes <= (0.1 * EA.TotalPosts) THEN 'Top 10%'
        WHEN EA.RankByUpvotes <= (0.25 * EA.TotalPosts) THEN 'Top 25%'
        ELSE 'Below Top 25%'
    END AS PerformanceCategory
FROM ExtendedAnalytics EA
WHERE EA.BadgeCount > 0
ORDER BY EA.Upvotes DESC, EA.CommentCount DESC;