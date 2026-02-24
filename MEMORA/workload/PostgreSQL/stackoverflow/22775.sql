WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.PostTypeId,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVoteCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownVoteCount,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        COALESCE((SELECT SUM(b.Class) FROM Badges b WHERE b.UserId = p.OwnerUserId), 0) AS TotalBadgeLevel
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
AggregatedData AS (
    SELECT 
        rp.OwnerUserId,
        COUNT(*) AS TotalPosts,
        SUM(rp.UpVoteCount) AS TotalUpVotes,
        SUM(rp.DownVoteCount) AS TotalDownVotes,
        SUM(rp.CommentCount) AS TotalComments,
        AVG(rp.TotalBadgeLevel) AS AvgBadgeLevel
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
    GROUP BY 
        rp.OwnerUserId
),
FilteredUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        au.OwnerUserId,
        au.TotalPosts,
        au.TotalUpVotes,
        au.TotalDownVotes,
        au.TotalComments,
        au.AvgBadgeLevel
    FROM 
        Users u
    LEFT JOIN 
        AggregatedData au ON u.Id = au.OwnerUserId
    WHERE 
        u.Reputation > 1000 OR 
        (u.Reputation IS NULL AND EXISTS (SELECT 1 FROM Badges WHERE UserId = u.Id AND Class = 1))
)
SELECT 
    fu.DisplayName,
    fy.TotalPosts,
    fy.TotalUpVotes,
    fy.TotalDownVotes,
    fy.TotalComments,
    fy.AvgBadgeLevel,
    COALESCE(NULLIF(fu.TotalUpVotes, 0), 1) AS SafeUpVotes,
    COALESCE(NULLIF(fu.TotalDownVotes, 0), 1) AS SafeDownVotes
FROM 
    FilteredUsers fu
LEFT OUTER JOIN 
    AggregatedData fy ON fu.OwnerUserId = fy.OwnerUserId
WHERE 
    fy.TotalPosts > 3 AND 
    (fy.TotalUpVotes - fy.TotalDownVotes) > 10
ORDER BY 
    fy.TotalComments DESC, 
    fy.TotalUpVotes DESC
LIMIT 100;