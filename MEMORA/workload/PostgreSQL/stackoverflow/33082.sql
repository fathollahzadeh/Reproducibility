
WITH RecentPostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Title,
        p.CreationDate,
        p.LastActivityDate,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,  
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount, 
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.LastActivityDate DESC) AS UserPostRank 
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days' 
    GROUP BY 
        p.Id, p.OwnerUserId, p.Title, p.CreationDate, p.LastActivityDate
),

UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        AVG(v.BountyAmount) AS AverageBounty
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.Reputation
),

RankedPosts AS (
    SELECT 
        rpa.PostId,
        rpa.Title,
        rpa.CommentCount,
        rpa.UpVoteCount,
        rpa.DownVoteCount,
        rpa.OwnerUserId,
        ur.Reputation,
        ur.BadgeCount,
        ur.AverageBounty,
        rpa.UserPostRank
    FROM 
        RecentPostActivity rpa
    JOIN 
        UserReputation ur ON rpa.OwnerUserId = ur.UserId
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CommentCount,
    rp.UpVoteCount,
    rp.DownVoteCount,
    rp.Reputation,
    rp.BadgeCount,
    rp.AverageBounty,
    CASE 
        WHEN rp.UserPostRank = 1 THEN 'Top Post'
        WHEN rp.CommentCount > 10 THEN 'Popular Post'
        ELSE 'Normal Post'
    END AS PostCategory
FROM 
    RankedPosts rp
WHERE 
    rp.UpVoteCount - rp.DownVoteCount > 5 
ORDER BY 
    rp.UpVoteCount DESC, rp.CommentCount DESC;
