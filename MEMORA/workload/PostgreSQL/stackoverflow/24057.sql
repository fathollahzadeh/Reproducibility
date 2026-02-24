
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS RankByCreation,
        RANK() OVER (ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
UserVoteStats AS (
    SELECT
        v.UserId,
        COUNT(CASE WHEN v.VoteTypeId IN (2, 6) THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId IN (3, 10) THEN 1 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.UserId
),
PostCommentCounts AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
PostBadges AS (
    SELECT 
        b.UserId, 
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    WHERE 
        b.Class = 1 
    GROUP BY 
        b.UserId
),
CompositeVotes AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        COUNT(CASE WHEN VoteTypeId = 6 THEN 1 ELSE 0 END) AS CloseVotes
    FROM 
        Votes
    GROUP BY 
        PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    up.UpVotes,
    down.DownVotes,
    COALESCE(cc.CommentCount, 0) AS CommentCount,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 6) AS CloseVoteCount,
    pb.BadgeNames,
    CASE 
        WHEN rp.RankByCreation <= 10 THEN 'New'
        WHEN rp.RankByScore <= 10 THEN 'Popular'
        ELSE 'Regular'
    END AS PostCategory
FROM 
    RankedPosts rp
LEFT JOIN 
    UserVoteStats up ON up.UserId = rp.PostId 
LEFT JOIN 
    UserVoteStats down ON down.UserId = rp.PostId 
LEFT JOIN 
    PostCommentCounts cc ON cc.PostId = rp.PostId
LEFT JOIN 
    PostBadges pb ON pb.UserId = rp.PostId
LEFT JOIN 
    CompositeVotes cv ON cv.PostId = rp.PostId
WHERE 
    rp.RankByCreation <= 20 
    OR rp.RankByScore <= 20
ORDER BY 
    rp.CreationDate DESC, rp.Score DESC;
