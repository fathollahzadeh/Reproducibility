
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS RankByViewCount,
        COUNT(c.Id) AS CommentCount,
        MAX(v.CreationDate) AS LastVoteDate,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 1 THEN v.Id END) AS AcceptCount,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 2 THEN v.Id END) AS UpVoteCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS TagsList
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    LEFT JOIN 
        unnest(string_to_array(p.Tags, ',')) AS t(TagName) ON t.TagName IS NOT NULL
    WHERE 
        p.CreationDate > CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '90 days'
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.Score
),
RecentHistory AS (
    SELECT
        ph.PostId,
        ph.Comment AS CloseReason,
        ph.CreationDate,
        PHT.Name AS HistoryType
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes PHT ON ph.PostHistoryTypeId = PHT.Id
    WHERE 
        ph.CreationDate > CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days'
        AND PHT.Id IN (10, 11, 12)  
),
FilteredPosts AS (
    SELECT 
        rp.*,
        CASE 
            WHEN rp.RankByViewCount <= 10 THEN 'Top Views'
            ELSE 'Other'
        END AS ViewCategory,
        COALESCE(rh.CloseReason, 'No recent action') AS RecentAction
    FROM 
        RankedPosts rp
    LEFT JOIN 
        RecentHistory rh ON rp.PostId = rh.PostId
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.ViewCount,
    fp.Score,
    fp.CommentCount,
    fp.LastVoteDate,
    fp.AcceptCount,
    fp.UpVoteCount,
    fp.TagsList,
    fp.ViewCategory,
    fp.RecentAction
FROM 
    FilteredPosts fp
WHERE 
    fp.ViewCount IS NOT NULL
    AND (fp.AcceptCount > 0 OR fp.UpVoteCount > 10)
ORDER BY 
    fp.Score DESC, 
    fp.ViewCount DESC
LIMIT 50;
