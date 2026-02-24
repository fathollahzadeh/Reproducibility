
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
RecentPosts AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.AnswerCount,
        rp.CommentCount,
        u.DisplayName AS OwnerDisplayName,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 2) AS UpVotes,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 3) AS DownVotes,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = rp.PostId) AS TotalComments,
        (SELECT STRING_AGG(b.Name, ', ') FROM Badges b WHERE b.UserId = rp.OwnerUserId) AS OwnerBadges
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.OwnerUserId = u.Id
    WHERE 
        rp.rn = 1 
),
PostHistoryData AS (
    SELECT 
        p.Id AS PostId,
        COALESCE(ph.Comment, 'No Comments') AS PostHistoryComment,
        ph.CreationDate AS HistoryDate,
        ph.UserDisplayName AS EditorName
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId 
    WHERE 
        p.Score > 0 
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.AnswerCount,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes,
    rp.TotalComments,
    rp.OwnerBadges,
    ph.PostHistoryComment,
    ph.HistoryDate,
    ph.EditorName
FROM 
    RecentPosts rp
LEFT JOIN 
    PostHistoryData ph ON rp.PostId = ph.PostId
ORDER BY 
    rp.Score DESC, rp.CreationDate DESC
LIMIT 100;
