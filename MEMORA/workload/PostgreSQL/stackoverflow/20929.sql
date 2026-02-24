
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 2 THEN v.UserId END) AS UpvoteCount,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 3 THEN v.UserId END) AS DownvoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY COUNT(c.Id) DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName
),
TopRatedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        (rp.UpvoteCount - rp.DownvoteCount) AS NetVotes,
        CASE 
            WHEN rp.CommentCount IS NULL THEN 'No Comments Yet'
            ELSE CONCAT(rp.CommentCount, ' Comments')
        END AS CommentStatus
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
),
PostHistorySummary AS (
    SELECT 
        ph.PostId, 
        ARRAY_AGG(DISTINCT pht.Name) AS HistoryTypes 
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    trp.PostId,
    trp.Title,
    trp.OwnerDisplayName,
    trp.NetVotes,
    trp.CommentStatus,
    COALESCE(phs.HistoryTypes, ARRAY[]::TEXT[]) AS HistoryTypes,
    CASE 
        WHEN trp.NetVotes > 0 THEN 'Trending'
        WHEN trp.NetVotes = 0 THEN 'Neutral'
        ELSE 'Declining'
    END AS TrendStatus
FROM 
    TopRatedPosts trp
LEFT JOIN 
    PostHistorySummary phs ON trp.PostId = phs.PostId
ORDER BY 
    trp.NetVotes DESC, trp.CommentStatus DESC;
