
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AcceptedAnswerId,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AcceptedAnswerId, p.OwnerUserId
),
TopComments AS (
    SELECT 
        c.PostId,
        c.UserId,
        c.Text,
        c.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY c.PostId ORDER BY c.Score DESC) AS CommentRank
    FROM 
        Comments c
),
PostVoteStats AS (
    SELECT 
        postId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        postId
),
PopularPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        COALESCE(pvs.UpVotes, 0) AS UpVotes,
        COALESCE(pvs.DownVotes, 0) AS DownVotes,
        rp.CommentCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostVoteStats pvs ON rp.PostId = pvs.postId
    WHERE 
        rp.rn <= 5 
)
SELECT 
    pp.PostId,
    pp.Title,
    pp.UpVotes,
    pp.DownVotes,
    COALESCE(tc.Text, 'No comments') AS TopComment,
    pp.CommentCount
FROM 
    PopularPosts pp
LEFT JOIN 
    TopComments tc ON pp.PostId = tc.PostId AND tc.CommentRank = 1
ORDER BY 
    pp.UpVotes DESC,
    pp.CommentCount DESC
LIMIT 10;
