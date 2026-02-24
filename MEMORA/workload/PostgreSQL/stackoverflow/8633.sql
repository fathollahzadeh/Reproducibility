WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        COUNT(c.Id) AS CommentCount,
        SUM(v.BountyAmount) AS TotalBounties,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),
PostStatistics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        ue.CommentCount AS UserComments,
        ue.TotalBounties,
        ue.UpVotes,
        ue.DownVotes,
        rp.Rank
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserEngagement ue ON rp.PostId IN (SELECT ParentId FROM Posts WHERE ParentId IS NOT NULL)
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.AnswerCount,
    ps.UserComments,
    ps.TotalBounties,
    ps.UpVotes,
    ps.DownVotes,
    ps.Rank
FROM 
    PostStatistics ps
WHERE 
    ps.Rank <= 5
ORDER BY 
    ps.Score DESC, ps.ViewCount DESC;