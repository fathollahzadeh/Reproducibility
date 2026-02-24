WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        DENSE_RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS RankViews
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= (cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year')
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesCount
    FROM 
        Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN pht.Name = 'Edit Title' THEN ph.CreationDate END) AS LastEditedTitle,
        MAX(CASE WHEN pht.Name = 'Edit Body' THEN ph.CreationDate END) AS LastEditedBody,
        COUNT(CASE WHEN pht.Name = 'Post Closed' THEN 1 END) AS CloseCount
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId, 
    rp.Title, 
    rp.Score, 
    rp.ViewCount,
    ue.DisplayName AS UserWhoCreatedPost,
    CASE 
        WHEN ph.LastEditedTitle IS NOT NULL THEN 'Edited'
        ELSE 'Not Edited'
    END AS TitleEditStatus,
    ph.CloseCount,
    ue.VoteCount,
    ue.UpVotesCount,
    ue.DownVotesCount
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistoryDetails ph ON rp.PostId = ph.PostId
LEFT JOIN 
    Users u ON rp.PostId = u.Id  
LEFT JOIN 
    UserEngagement ue ON u.Id = ue.UserId
WHERE 
    rp.RankScore <= 5 
    OR rp.RankViews <= 5
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC;