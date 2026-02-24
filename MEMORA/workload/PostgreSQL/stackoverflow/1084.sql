WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        u.DisplayName AS Author,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
        AND p.PostTypeId = 1  
),
PostVoteDetails AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId IN (2, 8) THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN VoteTypeId = 6 THEN 1 END) AS CloseVotes,
        COUNT(CASE WHEN VoteTypeId = 7 THEN 1 END) AS ReopenVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LatestCloseDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        ph.PostId
),
FinalResults AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.AnswerCount,
        rp.Author,
        COALESCE(pvd.UpVotes, 0) AS UpVotes,
        COALESCE(pvd.DownVotes, 0) AS DownVotes,
        COALESCE(pvd.CloseVotes, 0) AS CloseVotes,
        COALESCE(pvd.ReopenVotes, 0) AS ReopenVotes,
        cp.LatestCloseDate
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostVoteDetails pvd ON rp.PostId = pvd.PostId
    LEFT JOIN 
        ClosedPosts cp ON rp.PostId = cp.PostId
    WHERE 
        rp.UserPostRank = 1
)
SELECT 
    PostId,
    Title,
    CreationDate,
    ViewCount,
    Score,
    AnswerCount,
    Author,
    UpVotes,
    DownVotes,
    CloseVotes,
    ReopenVotes,
    CASE 
        WHEN LatestCloseDate IS NOT NULL THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus
FROM 
    FinalResults
ORDER BY 
    CreationDate DESC
LIMIT 100;