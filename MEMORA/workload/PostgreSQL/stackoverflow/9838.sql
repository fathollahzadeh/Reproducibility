WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount, 
        COALESCE(u.Reputation, 0) AS UserReputation,
        ROW_NUMBER() OVER (PARTITION BY p.Title ORDER BY p.CreationDate DESC) AS RN
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
PostVoteCounts AS (
    SELECT 
        PostId, 
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN VoteTypeId = 1 THEN 1 END) AS AcceptedVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
FinalResults AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.CreationDate, 
        rp.Score, 
        rp.ViewCount, 
        rp.UserReputation,
        pvc.UpVotes, 
        pvc.DownVotes, 
        pvc.AcceptedVotes
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostVoteCounts pvc ON rp.PostId = pvc.PostId
    WHERE 
        rp.RN = 1
)
SELECT 
    Title, 
    CreationDate, 
    Score, 
    ViewCount, 
    UserReputation, 
    UpVotes, 
    DownVotes, 
    AcceptedVotes
FROM 
    FinalResults
ORDER BY 
    ViewCount DESC, 
    Score DESC 
LIMIT 10;