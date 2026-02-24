
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        p.AnswerCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPost
    FROM 
        Posts p
    WHERE 
        p.CreationDate > CURRENT_DATE - INTERVAL '5 years'
),
UserVoteStats AS (
    SELECT 
        v.UserId,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS Downvotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.UserId
),
PostHistoryAgg AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN pht.Name = 'Post Closed' THEN ph.CreationDate END) AS LastClosedDate,
        COUNT(*) AS EditCount
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentsCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
)
SELECT 
    p.PostId,
    p.Title,
    p.CreationDate,
    u.DisplayName AS OwnerDisplayName,
    p.Score,
    p.AnswerCount,
    pu.Upvotes,
    pu.Downvotes,
    pa.LastClosedDate,
    pc.CommentsCount,
    CASE 
        WHEN pa.EditCount > 5 THEN 'Highly Edited'
        WHEN pa.EditCount BETWEEN 2 AND 5 THEN 'Moderately Edited'
        ELSE 'Rarely Edited'
    END AS EditFrequencyLabel
FROM 
    RankedPosts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    UserVoteStats pu ON u.Id = pu.UserId
LEFT JOIN 
    PostHistoryAgg pa ON p.PostId = pa.PostId
LEFT JOIN 
    PostComments pc ON p.PostId = pc.PostId
WHERE 
    p.RankScore = 1
    AND (p.AnswerCount > 0 OR pu.Upvotes > 10)
ORDER BY 
    p.CreationDate DESC;
