WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.Score IS NOT NULL
        AND p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
UserScores AS (
    SELECT 
        u.Id AS UserId,
        SUM(CASE WHEN v.VoteTypeId IN (2, 8) THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
        COUNT(b.Id) AS BadgesCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.UserDisplayName,
        ph.Comment,
        ph.CreationDate,
        LAG(ph.CreationDate) OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate) AS PrevEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
        AND ph.PostHistoryTypeId IN (4, 5, 10)  
),
MergedPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.Score, 
        us.TotalUpvotes,
        us.TotalDownvotes,
        us.BadgesCount,
        COALESCE(RANK() OVER (ORDER BY rp.Score DESC), 0) AS MergedRank,
        COALESCE(rph.UserDisplayName, 'No recent edits') AS LastEditor,
        COALESCE(rph.Comment, '') AS LastEditComment,
        rph.PrevEditDate
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserScores us ON rp.PostId = us.UserId
    LEFT JOIN 
        RecentPostHistory rph ON rp.PostId = rph.PostId
)
SELECT 
    mp.PostId,
    mp.Title,
    mp.Score,
    mp.TotalUpvotes,
    mp.TotalDownvotes,
    mp.BadgesCount,
    mp.MergedRank,
    mp.LastEditor,
    mp.LastEditComment,
    CASE 
        WHEN mp.PrevEditDate IS NULL THEN 'No previous edits'
        WHEN cast('2024-10-01 12:34:56' as timestamp) - mp.PrevEditDate <= INTERVAL '7 days' THEN 'Edited recently'
        ELSE 'Not edited recently'
    END AS EditStatus
FROM 
    MergedPosts mp
WHERE 
    mp.Score > (SELECT AVG(Score) FROM Posts)  
ORDER BY 
    mp.Score DESC,
    mp.MergedRank ASC
LIMIT 50;