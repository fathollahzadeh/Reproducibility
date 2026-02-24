WITH UserVoteCounts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        u.Id, u.DisplayName
),
TopPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND p.Score > 0
),
PostWithBadges AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeClass
    FROM 
        Posts p
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    WHERE 
        b.Class IN (1, 2, 3) 
    GROUP BY 
        p.Id, p.Title
),
ClosedPostDetails AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS CloseVotes,
        MAX(ph.CreationDate) AS LastClosedDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 
    GROUP BY 
        ph.PostId
),
FinalOutput AS (
    SELECT 
        p.Id,
        p.Title,
        u.DisplayName,
        COALESCE(uv.TotalVotes, 0) AS UserVotes,
        COALESCE(pb.BadgeCount, 0) AS BadgeCount,
        COALESCE(pb.HighestBadgeClass, 0) AS HighestBadgeClass,
        COALESCE(cp.CloseVotes, 0) AS CloseVotes,
        COALESCE(cp.LastClosedDate, '1900-01-01') AS LastClosedDate
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        UserVoteCounts uv ON u.Id = uv.UserId
    LEFT JOIN 
        PostWithBadges pb ON p.Id = pb.PostId
    LEFT JOIN 
        ClosedPostDetails cp ON p.Id = cp.PostId
    WHERE 
        (uv.TotalVotes IS NULL OR uv.TotalVotes > 10) 
        AND u.Reputation >= 100 
)
SELECT 
    *,
    CASE 
        WHEN CloseVotes > 0 THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus
FROM 
    FinalOutput
WHERE 
    BadgeCount > 0 OR CloseVotes > 0
ORDER BY 
    HighestBadgeClass DESC, UserVotes DESC, Title;