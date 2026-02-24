WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(v.UpVotes, 0)) AS TotalUpVotes,
        SUM(COALESCE(v.DownVotes, 0)) AS TotalDownVotes,
        ROW_NUMBER() OVER (ORDER BY COUNT(p.Id) DESC) AS Rank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        (SELECT 
             PostId, 
             SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
             SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
         FROM 
             Votes 
         GROUP BY 
             PostId) v ON p.Id = v.PostId
    WHERE 
        u.Reputation > 0
    GROUP BY 
        u.Id, u.DisplayName
), RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '7 days'
)
SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.PostCount,
    ups.TotalUpVotes,
    ups.TotalDownVotes,
    rp.PostId,
    rp.Title,
    rp.CreationDate AS RecentPostDate,
    rp.UserPostRank,
    COALESCE(ph.Comment, 'No comments available') AS PostHistoryComment
FROM 
    UserPostStats ups 
LEFT JOIN 
    RecentPosts rp ON ups.UserId = rp.OwnerUserId AND rp.UserPostRank = 1
LEFT JOIN 
    PostHistory ph ON rp.PostId = ph.PostId AND ph.CreationDate = (
        SELECT MAX(CreationDate)
        FROM PostHistory ph_sub
        WHERE ph_sub.PostId = rp.PostId AND ph_sub.UserId IS NOT NULL
    )
WHERE 
    ups.Rank <= 10
ORDER BY 
    ups.Rank;