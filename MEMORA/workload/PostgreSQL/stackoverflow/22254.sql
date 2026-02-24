WITH RecursivePostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        COALESCE(v.UpVotes, 0) AS UpVoteCount,
        COALESCE(v.DownVotes, 0) AS DownVoteCount,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS RecentEditOrder,
        CASE 
            WHEN p.PostTypeId = 1 THEN ph.Comment
            ELSE NULL 
        END AS CloseReason
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId, 
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
        FROM 
            Votes
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId = 10 
),
PostWithDetails AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.CreationDate,
        ps.OwnerUserId,
        ps.UpVoteCount,
        ps.DownVoteCount,
        ps.ViewCount,
        ps.RecentEditOrder,
        ps.CloseReason,
        ROW_NUMBER() OVER (PARTITION BY ps.OwnerUserId ORDER BY ps.ViewCount DESC) AS UserPostRank
    FROM 
        RecursivePostStats ps
)
SELECT 
    u.DisplayName AS OwnerName,
    p.Title,
    p.CreationDate,
    p.UpVoteCount,
    p.DownVoteCount,
    p.ViewCount,
    p.CloseReason,
    CASE 
        WHEN p.RecentEditOrder >= 1 THEN 'Edited Recently' 
        ELSE 'Not Edited Recently' 
    END AS RecentEditStatus,
    CASE 
        WHEN p.UserPostRank = 1 THEN 'Top Post'
        ELSE 'Other Post'
    END AS PostRank
FROM 
    PostWithDetails p
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.CloseReason IS NOT NULL 
    OR (p.UpVoteCount - p.DownVoteCount) > 10
ORDER BY 
    p.ViewCount DESC, 
    p.CreationDate DESC
OFFSET 10 ROWS FETCH NEXT 20 ROWS ONLY;