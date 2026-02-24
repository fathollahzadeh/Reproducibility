WITH RecursivePostHistory AS (
    SELECT 
        ph.Id,
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        ph.PostHistoryTypeId,
        ph.Comment,
        ph.Text,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS HistoryRank
    FROM 
        PostHistory ph
),
UserVoteCounts AS (
    SELECT 
        v.UserId,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.UserId
),
PopularUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        COALESCE(uc.UpVotes, 0) AS UpVotes,
        COALESCE(uc.DownVotes, 0) AS DownVotes,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC, uc.UpVotes DESC) AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        UserVoteCounts uc ON u.Id = uc.UserId
),
ClosedPosts AS (
    SELECT 
        p.Id AS ClosedPostId,
        p.Title,
        MAX(ph.CreationDate) AS LastClosed
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId 
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        p.Id, p.Title
),
RecentActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.LastActivityDate,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId 
    WHERE 
        p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.LastActivityDate
)
SELECT 
    pu.DisplayName,
    pu.Reputation,
    ph.Comment AS LastEditComment,
    cp.Title AS ClosedPostTitle,
    ra.CommentCount AS RecentComments,
    ra.UpVoteCount 
FROM 
    PopularUsers pu
LEFT JOIN 
    RecursivePostHistory ph ON pu.Id = ph.UserId AND ph.HistoryRank = 1
LEFT JOIN 
    ClosedPosts cp ON ph.PostId = cp.ClosedPostId
LEFT JOIN 
    RecentActivity ra ON ra.PostId = cp.ClosedPostId
WHERE 
    pu.UserRank <= 10
ORDER BY 
    pu.Reputation DESC, ra.CommentCount DESC;