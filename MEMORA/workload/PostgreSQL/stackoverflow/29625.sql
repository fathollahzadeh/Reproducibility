
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        STRING_AGG(t.TagName, ', ') AS TagsList,
        COUNT(DISTINCT c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS RankByDate,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    LEFT JOIN 
        Tags t ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId, p.Score
),
TopRankedPosts AS (
    SELECT 
        *,
        CASE 
            WHEN RankByDate <= 5 THEN 'Recent'
            WHEN RankByScore <= 5 THEN 'Popular'
            ELSE 'Other'
        END AS PostCategory
    FROM 
        RankedPosts
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionsAsked,
        COUNT(DISTINCT c.Id) AS CommentsMade,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesReceived, 
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesReceived 
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId 
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON v.UserId = u.Id AND v.PostId IN (SELECT Id FROM Posts)
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    trp.PostID,
    trp.Title,
    trp.CreationDate,
    u.DisplayName AS Owner,
    u.Reputation AS OwnerReputation,
    trp.TagsList,
    trp.CommentCount,
    trp.PostCategory,
    us.QuestionsAsked,
    us.CommentsMade,
    us.UpVotesReceived,
    us.DownVotesReceived
FROM 
    TopRankedPosts trp
JOIN 
    Users u ON trp.OwnerUserId = u.Id
JOIN 
    UserStats us ON u.Id = us.UserId
WHERE 
    trp.PostCategory IN ('Recent', 'Popular')
ORDER BY 
    trp.PostCategory DESC, trp.Score DESC, trp.CreationDate DESC;
