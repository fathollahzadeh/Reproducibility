WITH RECURSIVE UserPosts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        1 AS Level
    FROM
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 1000 

    UNION ALL

    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        Level + 1
    FROM 
        UserPosts up
    JOIN 
        Posts p ON up.PostId = p.ParentId 
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        up.Level < 5 
),

VoteStatistics AS (
    SELECT 
        p.Id AS PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),

PostHistorySummary AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastEdited,
        MIN(ph.CreationDate) AS FirstEdited,
        COUNT(*) AS EditCount,
        STRING_AGG(DISTINCT ph.Comment, '; ') AS EditComments 
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6, 24) 
    GROUP BY 
        ph.PostId
)

SELECT 
    up.UserId,
    up.DisplayName,
    up.PostId,
    up.Title,
    up.CreationDate,
    up.Score,
    COALESCE(vs.UpVotes, 0) AS UpVotes,
    COALESCE(vs.DownVotes, 0) AS DownVotes,
    COALESCE(phs.EditCount, 0) AS EditCount,
    phs.LastEdited,
    phs.FirstEdited,
    phs.EditComments
FROM 
    UserPosts up
LEFT JOIN 
    VoteStatistics vs ON up.PostId = vs.PostId
LEFT JOIN 
    PostHistorySummary phs ON up.PostId = phs.PostId
WHERE 
    up.Score > 0 
ORDER BY 
    up.Score DESC, 
    up.CreationDate ASC;