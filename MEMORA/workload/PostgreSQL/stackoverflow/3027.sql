
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
PostVoteData AS (
    SELECT 
        p.Id AS PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
PostComments AS (
    SELECT 
        PostId,
        COUNT(*) AS CommentCount,
        MAX(CreationDate) AS LastCommentDate
    FROM 
        Comments
    GROUP BY 
        PostId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS ClosedDate,
        ph.UserDisplayName AS ClosedBy
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
),
FinalResults AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.CreationDate,
        rp.OwnerDisplayName,
        COALESCE(pvd.UpVotes, 0) AS UpVotes,
        COALESCE(pvd.DownVotes, 0) AS DownVotes,
        COALESCE(pc.CommentCount, 0) AS CommentCount,
        COALESCE(cp.ClosedDate, NULL) AS ClosedDate,
        COALESCE(cp.ClosedBy, 'Not Closed') AS ClosedBy,
        rp.Score,
        rp.ViewCount,
        rp.UserPostRank -- Added UserPostRank to ensure proper grouping
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostVoteData pvd ON rp.Id = pvd.PostId
    LEFT JOIN 
        PostComments pc ON rp.Id = pc.PostId
    LEFT JOIN 
        ClosedPosts cp ON rp.Id = cp.PostId
)
SELECT 
    Id,
    Title,
    CreationDate,
    OwnerDisplayName,
    UpVotes,
    DownVotes,
    CommentCount,
    ClosedDate,
    ClosedBy,
    Score,
    ViewCount
FROM 
    FinalResults
WHERE 
    (UserPostRank = 1 AND Score >= 10) OR 
    (CommentCount > 5 AND ClosedBy = 'Not Closed')
ORDER BY 
    CreationDate DESC;
