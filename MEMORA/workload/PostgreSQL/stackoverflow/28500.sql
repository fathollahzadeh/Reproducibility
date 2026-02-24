
WITH TagCounts AS (
    SELECT 
        TRIM(tag) AS TagName, 
        COUNT(*) AS PostCount
    FROM (
        SELECT 
            UNNEST(string_to_array(SUBSTRING(Tags FROM 2 FOR LENGTH(Tags) - 2), '> <')) AS tag
        FROM 
            Posts
        WHERE 
            PostTypeId = 1 
    ) AS tags
    GROUP BY 
        TRIM(tag)
),
TopTags AS (
    SELECT 
        TagName, 
        PostCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS rn
    FROM 
        TagCounts
    WHERE 
        PostCount > 5 
),
PopularUsers AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        Users u 
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        UpVotes, 
        DownVotes,
        QuestionCount,
        CommentCount,
        ROW_NUMBER() OVER (ORDER BY UpVotes - DownVotes DESC, QuestionCount DESC) AS rn 
    FROM 
        PopularUsers
    WHERE 
        QuestionCount > 2 
),
PostHistoryInfo AS (
    SELECT 
        p.Id AS PostId, 
        p.Title,
        MAX(ph.CreationDate) AS LastEdited,
        COUNT(DISTINCT ph.Id) AS EditCount,
        ARRAY_AGG(DISTINCT ph.UserDisplayName) AS Editors
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title
)
SELECT 
    tt.TagName, 
    tt.PostCount, 
    tu.DisplayName AS TopUser, 
    tu.QuestionCount, 
    ph.PostId, 
    ph.Title, 
    ph.LastEdited, 
    ph.EditCount,
    ph.Editors
FROM 
    TopTags tt
JOIN 
    TopUsers tu ON tu.QuestionCount > 5 
JOIN 
    PostHistoryInfo ph ON ph.Title ILIKE '%' || tt.TagName || '%' 
WHERE 
    tu.rn <= 10 AND 
    tt.rn <= 10 
ORDER BY 
    tt.PostCount DESC, tu.UpVotes DESC;
