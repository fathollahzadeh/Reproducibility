
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' AND 
        p.Score > 0
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE 
            WHEN v.VoteTypeId = 2 THEN 1 
            ELSE 0 
        END) AS UpVotes,
        SUM(CASE 
            WHEN v.VoteTypeId = 3 THEN 1 
            ELSE 0 
        END) AS DownVotes,
        COUNT(c.Id) AS CommentCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostStatistics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        ue.DisplayName AS TopContributor,
        ue.UpVotes,
        ue.DownVotes,
        ue.CommentCount,
        COUNT(pl.RelatedPostId) AS RelatedPostsCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostLinks pl ON rp.PostId = pl.PostId
    LEFT JOIN 
        UserEngagement ue ON rp.PostId = (
            SELECT 
                p.OwnerUserId 
            FROM 
                Posts p 
            WHERE 
                p.Id = rp.PostId
        )
    WHERE 
        rp.Rank <= 5
    GROUP BY 
        rp.PostId, rp.Title, rp.CreationDate, rp.Score, ue.DisplayName, ue.UpVotes, ue.DownVotes, ue.CommentCount
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.Score,
    ps.UpVotes,
    ps.DownVotes,
    ps.CommentCount,
    ps.RelatedPostsCount,
    COALESCE(NULLIF(ps.TopContributor, ''), 'No Contributor') AS TopContributor
FROM 
    PostStatistics ps
ORDER BY 
    ps.Score DESC, ps.CreationDate DESC;
