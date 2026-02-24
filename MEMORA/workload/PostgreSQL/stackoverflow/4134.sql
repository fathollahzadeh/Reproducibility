
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        COALESCE(pc.CommentCount, 0) AS TotalComments,
        COALESCE(ua.VoteCount, 0) AS TotalVotes,
        ua.DisplayName AS VoterDisplayName
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostComments pc ON rp.PostId = pc.PostId
    LEFT JOIN 
        UserActivity ua ON rp.PostId IN (SELECT pl.RelatedPostId FROM PostLinks pl WHERE pl.PostId = rp.PostId)
    WHERE 
        rp.PostRank <= 10
)
SELECT 
    pd.Title,
    pd.Score,
    pd.ViewCount,
    pd.TotalComments,
    pd.TotalVotes,
    pd.VoterDisplayName AS VoterName 
FROM 
    PostDetails pd
ORDER BY 
    pd.Score DESC 
FETCH FIRST 20 ROWS ONLY;
