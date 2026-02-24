
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        COALESCE(UP.VoteCount, 0) AS UpVotes,
        COALESCE(DOWN.VoteCount, 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS VoteCount 
        FROM Votes 
        WHERE VoteTypeId = 2 
        GROUP BY PostId
    ) UP ON p.Id = UP.PostId
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS VoteCount 
        FROM Votes 
        WHERE VoteTypeId = 3 
        GROUP BY PostId
    ) DOWN ON p.Id = DOWN.PostId
),
TagPopularity AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    GROUP BY 
        t.TagName
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCreated,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.Score, 0)) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    rp.UpVotes,
    rp.DownVotes,
    tp.TagName,
    tp.PostCount,
    tp.TotalViews,
    ua.UserId,
    ua.DisplayName,
    ua.PostsCreated,
    ua.TotalViews AS UserTotalViews,
    ua.TotalScore
FROM 
    RankedPosts rp
LEFT JOIN 
    TagPopularity tp ON rp.Title LIKE CONCAT('%', tp.TagName, '%')
LEFT JOIN 
    UserActivity ua ON rp.OwnerUserId = ua.UserId
WHERE 
    rp.Rank <= 10
ORDER BY 
    rp.Score DESC, rp.CreationDate DESC;
