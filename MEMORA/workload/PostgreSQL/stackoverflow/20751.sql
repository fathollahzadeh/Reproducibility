WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        pt.Name AS PostType,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
VoteSummary AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
ClosedPostDetails AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.Comment
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        CASE 
            WHEN u.Reputation IS NULL THEN 0 
            ELSE u.Reputation
        END AS Reputation,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    COALESCE(vs.UpVotes, 0) AS UpVotes,
    COALESCE(vs.DownVotes, 0) AS DownVotes,
    COALESCE(cpd.Comment, 'No comment') AS CloseReasonComment,
    ur.Reputation AS UserReputation,
    ur.BadgeCount,
    CASE 
        WHEN rp.RankByScore <= 10 THEN 'Top Post'
        ELSE 'Regular Post'
    END AS PostCategory
FROM 
    RankedPosts rp
LEFT JOIN 
    VoteSummary vs ON rp.PostId = vs.PostId
LEFT JOIN 
    ClosedPostDetails cpd ON rp.PostId = cpd.PostId
LEFT JOIN 
    Users u ON rp.CreationDate = u.CreationDate 
LEFT JOIN 
    UserReputation ur ON u.Id = ur.UserId
WHERE 
    rp.RankByScore BETWEEN 1 AND 20
ORDER BY 
    rp.CreationDate DESC, rp.Score DESC;