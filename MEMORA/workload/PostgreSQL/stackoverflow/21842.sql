WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        COUNT(c.Id) AS CommentCount,
        MAX(b.Date) AS LastBadgeDate
    FROM
        Posts p
    LEFT JOIN
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Badges b ON b.UserId = p.OwnerUserId
    WHERE
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY
        p.Id, p.Title, p.PostTypeId, p.Score, p.ViewCount
),
PopularPosts AS (
    SELECT
        *,
        CASE 
            WHEN RankScore <= 10 THEN 'Top 10'
            ELSE 'Other'
        END AS Popularity
    FROM
        RankedPosts
),
PostHistoryAnalysis AS (
    SELECT
        ph.PostId,
        COUNT(DISTINCT CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN ph.Id END) AS CloseReopenCount,
        COUNT(DISTINCT CASE WHEN ph.PostHistoryTypeId = 24 THEN ph.Id END) AS SuggestedEditCount
    FROM
        PostHistory ph
    GROUP BY
        ph.PostId
)
SELECT
    pp.PostId,
    pp.Title,
    pp.Popularity,
    pp.Score,
    pp.ViewCount,
    COALESCE(pha.CloseReopenCount, 0) AS CloseReopenCount,
    COALESCE(pha.SuggestedEditCount, 0) AS SuggestedEditCount,
    CASE 
        WHEN pp.ViewCount > 100 THEN 'Highly Viewed'
        WHEN pp.ViewCount BETWEEN 50 AND 100 THEN 'Moderately Viewed'
        ELSE 'Low Views'
    END AS ViewCategory,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = pp.PostId AND v.VoteTypeId = 3) AS DownVoteCount,
    (SELECT CASE WHEN EXISTS (
        SELECT 1
        FROM Votes v
        WHERE v.PostId = pp.PostId AND v.VoteTypeId = 2
        ) THEN 'Yes' ELSE 'No' END) AS HasUpVotes
FROM
    PopularPosts pp
LEFT JOIN
    PostHistoryAnalysis pha ON pp.PostId = pha.PostId
WHERE
    pp.Popularity = 'Top 10'
ORDER BY
    pp.Score DESC,
    pp.ViewCount DESC;