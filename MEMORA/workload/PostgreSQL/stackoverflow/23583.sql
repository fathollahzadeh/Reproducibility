WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title, 
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.LastActivityDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank,
        COALESCE(v.VoteSum, 0) AS TotalVotes
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId, 
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 WHEN VoteTypeId = 3 THEN -1 ELSE 0 END) AS VoteSum
        FROM 
            Votes
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
), 
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.Rank, 
        rp.TotalVotes,
        PH.UserDisplayName,
        PH.CreationDate AS HistoryDate,
        PH.Comment AS HistoryComment,
        PH.PostHistoryTypeId,
        DENSE_RANK() OVER (PARTITION BY rp.PostId ORDER BY PH.CreationDate DESC) AS HistoryRank
    FROM 
        RankedPosts rp
    LEFT JOIN PostHistory PH ON rp.PostId = PH.PostId
    WHERE 
        PH.PostHistoryTypeId IN (10, 11, 12) 
), 
RecentActivity AS (
    SELECT 
        PostId,
        STRING_AGG(DISTINCT UserDisplayName, ', ') AS UsersResponsible,
        COUNT(*) AS ChangeCount
    FROM 
        PostDetails
    WHERE 
        HistoryRank = 1
    GROUP BY 
        PostId
), 
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        SUM(b.Class) AS TotalBadgePoints
    FROM 
        Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)

SELECT 
    pd.PostId, 
    pd.Title, 
    pd.Score, 
    pd.ViewCount, 
    pd.Rank, 
    pd.TotalVotes,
    ra.UsersResponsible,
    ra.ChangeCount,
    COALESCE(ur.TotalBadgePoints, 0) AS BadgePoints,
    CASE 
        WHEN pd.TotalVotes IS NULL THEN 'No Votes' 
        ELSE CONCAT(pd.TotalVotes, ' Total Votes')
    END AS VoteMessage,
    CASE 
        WHEN pd.Score > 0 THEN 'Prominent Post'
        WHEN pd.Score < 0 THEN 'Controversial Post'
        ELSE 'Neutral Post'
    END AS Sentiment
FROM 
    PostDetails pd
LEFT JOIN RecentActivity ra ON pd.PostId = ra.PostId
LEFT JOIN Users u ON pd.PostId = u.Id
LEFT JOIN UserReputation ur ON pd.PostId = ur.UserId
WHERE 
    pd.Rank <= 5 
    AND pd.HistoryRank = 1
ORDER BY 
    pd.Score DESC, 
    pd.ViewCount DESC;