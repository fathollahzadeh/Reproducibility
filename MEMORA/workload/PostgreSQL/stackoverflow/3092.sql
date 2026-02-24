WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        COALESCE(b.Name, 'No Badge') AS UserBadge
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Badges b ON u.Id = b.UserId AND b.Class = 1 
    WHERE 
        p.PostTypeId = 1 
),
UserVoteCounts AS (
    SELECT 
        v.UserId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.UserId
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
)
SELECT 
    rp.Title,
    rp.Score,
    rp.CreationDate,
    rp.UserBadge,
    COALESCE(uc.UpVotes, 0) AS UpVotes,
    COALESCE(uc.DownVotes, 0) AS DownVotes,
    COALESCE(pc.CommentCount, 0) AS CommentCount
FROM 
    RankedPosts rp
LEFT JOIN 
    UserVoteCounts uc ON rp.OwnerUserId = uc.UserId
LEFT JOIN 
    PostComments pc ON rp.Id = pc.PostId
WHERE 
    rp.PostRank = 1 
ORDER BY 
    rp.Score DESC,
    rp.CreationDate DESC
LIMIT 10;