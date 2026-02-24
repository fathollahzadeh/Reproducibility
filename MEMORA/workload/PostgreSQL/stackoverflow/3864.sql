
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(v.BountyAmount) AS TotalBounties,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT p.Id) DESC) AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId AND v.VoteTypeId IN (8, 9)  
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 100  
    GROUP BY 
        u.Id, u.DisplayName
),
PostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT pl.RelatedPostId) AS RelatedPostsCount,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostLinks pl ON p.Id = pl.PostId
    WHERE 
        p.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
),
RankedPosts AS (
    SELECT 
        pa.PostId,
        pa.Title,
        pa.CreationDate,
        pa.UpVotes,
        pa.DownVotes,
        pa.CommentCount,
        pa.RelatedPostsCount,
        ROW_NUMBER() OVER (ORDER BY (pa.UpVotes - pa.DownVotes) DESC) AS ScoreRank
    FROM 
        PostActivity pa
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.PostCount,
    ua.TotalBounties,
    ua.BadgeCount,
    rp.Title AS TopPostTitle,
    rp.UpVotes,
    rp.DownVotes,
    rp.CommentCount,
    rp.RelatedPostsCount
FROM 
    UserActivity ua
LEFT JOIN 
    RankedPosts rp ON ua.UserRank = 1  
WHERE 
    (ua.TotalBounties IS NULL OR ua.TotalBounties > 0)  
ORDER BY 
    ua.PostCount DESC, ua.TotalBounties DESC;
