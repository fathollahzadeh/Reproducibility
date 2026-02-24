WITH UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.Reputation
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        COALESCE(b.Name, 'No Badge') AS BadgeName,
        COALESCE(t.TagName, 'No Tag') AS TagName,
        COUNT(c.Id) AS CommentCount,
        AVG(ct.Reputation) AS LastEditor_Reputation
    FROM 
        Posts p
    LEFT JOIN 
        Badges b ON b.UserId = p.OwnerUserId
    LEFT JOIN 
        Tags t ON t.ExcerptPostId = p.Id
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Users ct ON ct.Id = p.LastEditorUserId
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        p.Id, b.Name, t.TagName
),
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS HistoryCount,
        MAX(ph.CreationDate) AS LastHistoryDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
IntegratedStats AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.Score,
        pd.CreationDate,
        pd.BadgeName,
        pd.TagName,
        pd.CommentCount,
        pvs.VoteCount,
        pvs.UpVotes,
        pvs.DownVotes,
        phs.HistoryCount,
        phs.LastHistoryDate,
        ROW_NUMBER() OVER (PARTITION BY pd.TagName ORDER BY pd.Score DESC) AS TagRank
    FROM 
        PostDetails pd
    LEFT JOIN 
        UserVoteStats pvs ON pd.PostId = pvs.UserId
    LEFT JOIN 
        PostHistoryStats phs ON pd.PostId = phs.PostId
)
SELECT 
    *,
    CASE 
        WHEN TagRank <= 5 THEN 'Top Tag Posts'
        ELSE 'Other Posts'
    END AS PostClassification,
    NULLIF(UpVotes, 0) AS NonZeroUpVotes,
    COALESCE(HistoryCount, 0) * (CASE WHEN BadgeName = 'Gold' THEN 2 ELSE 1 END) AS WeightedHistoryCount
FROM 
    IntegratedStats
WHERE 
    Score > 10 
    AND CreationDate <= (cast('2024-10-01' as date) - INTERVAL '6 months')
    AND (CommentCount IS NULL OR CommentCount > 5)
ORDER BY 
    Score DESC, CreationDate ASC;