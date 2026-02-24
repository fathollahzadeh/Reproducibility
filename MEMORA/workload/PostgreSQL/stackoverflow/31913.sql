
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.CreationDate,
        p.PostTypeId,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.PostTypeId, p.Score, p.ViewCount
),
UserEngagement AS (
    SELECT 
        u.Id AS UserID,
        u.DisplayName,
        SUM(v.BountyAmount) AS TotalBounties,
        COUNT(DISTINCT v.PostId) AS BountyPosts,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopEngagedUsers AS (
    SELECT 
        ue.UserID,
        ue.DisplayName,
        ue.TotalBounties,
        ue.BountyPosts,
        ue.Upvotes,
        ue.Downvotes,
        RANK() OVER (ORDER BY ue.TotalBounties DESC, ue.Upvotes DESC) AS EngagementRank
    FROM 
        UserEngagement ue
)
SELECT 
    rp.PostID,
    rp.Title,
    rp.CreationDate,
    rp.PostTypeId,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    te.DisplayName AS TopUser,
    te.TotalBounties
FROM 
    RankedPosts rp
LEFT JOIN 
    TopEngagedUsers te ON te.UserID IN (
        SELECT 
            DISTINCT v.UserId 
        FROM 
            Votes v 
        WHERE 
            v.PostId = rp.PostID
    )
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.PostTypeId, rp.Score DESC, te.TotalBounties DESC NULLS LAST
FETCH FIRST 100 ROWS ONLY;
