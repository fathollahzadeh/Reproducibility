
WITH RecursivePostHistory AS (
    SELECT 
        p.Id AS PostId,
        ph.CreationDate,
        ph.Comment,
        ph.UserId,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
), UserVotes AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN vt.Name = 'UpMod' THEN 1 END) AS UpVoteCount,
        COUNT(CASE WHEN vt.Name = 'DownMod' THEN 1 END) AS DownVoteCount,
        COUNT(CASE WHEN vt.Name = 'AcceptedByOriginator' THEN 1 END) AS AcceptedVoteCount
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.PostId
), TagSummary AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t 
    LEFT JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    GROUP BY 
        t.Id, t.TagName
), RecentActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN ph.Comment IS NOT NULL THEN 1 ELSE 0 END) AS EditsCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        PostHistory ph ON ph.UserId = u.Id
    WHERE 
        u.LastAccessDate >= timestamp '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    p.Id AS PostId,
    p.Title AS PostTitle,
    recent.DisplayName AS Owner,
    ph.Comment AS LatestEditComment,
    ph.CreationDate AS LatestEditDate,
    up.UpVoteCount,
    down.DownVoteCount AS DownVotes,
    accepted.AcceptedVoteCount,
    ts.TagId,
    ts.TagName,
    ts.PostCount,
    recent.UserId,
    recent.PostCount AS RecentPostCount,
    recent.EditsCount AS RecentEditsCount
FROM 
    Posts p
LEFT JOIN 
    RecursivePostHistory ph ON p.Id = ph.PostId AND ph.rn = 1
LEFT JOIN 
    UserVotes up ON p.Id = up.PostId
LEFT JOIN 
    UserVotes down ON p.Id = down.PostId
LEFT JOIN 
    UserVotes accepted ON p.Id = accepted.PostId
LEFT JOIN 
    TagSummary ts ON p.Tags LIKE CONCAT('%', ts.TagName, '%')
LEFT JOIN 
    RecentActiveUsers recent ON recent.UserId = p.OwnerUserId
WHERE 
    p.CreationDate >= timestamp '2024-10-01 12:34:56' - INTERVAL '1 year' 
    AND (up.UpVoteCount > 0 OR down.DownVoteCount > 0)
ORDER BY 
    p.LastActivityDate DESC,
    p.Score DESC;
